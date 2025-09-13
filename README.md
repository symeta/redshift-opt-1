# redshift-opt-1

## 使用redshift遇到超长字符串兼容问题，即使使用super仍然会有这个问题，比如json的value超过65535不可用。解决这个问题有什么建议么？
### 1. 字符串分片存储
- 将长字符串拆分成多个字段
```sql
CREATE TABLE large_json_table (
    id INT,
    json_data SUPER
);
```
- Python预处理示例
```py
def split_large_string(text, chunk_size=60000):
    chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
    return {f"chunk_{i}": chunk for i, chunk in enumerate(chunks)}
```
    - 原始数据
```txt
large_text = "x" * 100000  # 超过65535字节
```
    - 分片处理
```json
chunked_data = {
    "metadata": {"total_chunks": 2, "original_length": len(large_text)},
    "content": split_large_string(large_text)
}
```
    - 插入Redshift
```sql
INSERT INTO large_json_table VALUES (
    1, 
    JSON_PARSE('{"metadata": {"total_chunks": 2}, "content": {"chunk_0": "...", "chunk_1": "..."}}')
);
```

### 2. 使用数组存储
- 将长字符串转换为字符串数组
```sql
INSERT INTO table VALUES (JSON_PARSE('{
    "id": 123,
    "large_content_array": ["chunk1_60k_chars", "chunk2_60k_chars", "chunk3_remaining"],
    "metadata": {"total_length": 150000}
}'));
```
- 查询时重组
```sql
SELECT 
    id,
    ARRAY_TO_STRING(json_data.large_content_array, '') as reconstructed_text
FROM table;
```

### 3. 外部存储引用
- 将大内容存储到S3，JSON中只保存引用
```sql
INSERT INTO table VALUES (JSON_PARSE('{
    "id": 123,
    "content_ref": {
        "type": "s3",
        "bucket": "my-bucket",
        "key": "large-content/123.txt",
        "size": 150000
    },
    "summary": "这是内容摘要..."
}'));
```

### 4. 压缩存储
```py
python
import gzip
import base64
import json

def compress_and_store(large_text):
    # 压缩
    compressed = gzip.compress(large_text.encode('utf-8'))
    encoded = base64.b64encode(compressed).decode('utf-8')
    
    # 如果压缩后仍然太大，再分片
    if len(encoded) > 60000:
        chunks = [encoded[i:i+60000] for i in range(0, len(encoded), 60000)]
        return {
            "compressed_chunks": chunks,
            "is_compressed": True,
            "original_size": len(large_text)
        }
    else:
        return {
            "compressed_data": encoded,
            "is_compressed": True,
            "original_size": len(large_text)
        }
```

### 5. 分表存储
- 主表存储元数据
```sql
CREATE TABLE json_metadata (
    id INT PRIMARY KEY,
    metadata SUPER
);
```
- 内容表存储大字段
```sql
CREATE TABLE json_content (
    id INT,
    chunk_order INT,
    content VARCHAR(65535)
);
```
- 插入数据
```sql
INSERT INTO json_metadata VALUES (1, JSON_PARSE('{"type": "article", "title": "..."}'));
INSERT INTO json_content VALUES 
    (1, 0, 'first_chunk_of_large_content'),
    (1, 1, 'second_chunk_of_large_content');
```
- 查询时关联
```sql
SELECT 
    m.metadata,
    STRING_AGG(c.content, '' ORDER BY c.chunk_order) as full_content
FROM json_metadata m
JOIN json_content c ON m.id = c.id
WHERE m.id = 1
GROUP BY m.id, m.metadata;
```

## 6. 预处理截断
- 简单截断（如果可以接受数据丢失）
```sql
SELECT JSON_PARSE('{
    "id": 123,
    "content": "' || LEFT(large_text, 60000) || '",
    "truncated": true,
    "original_length": ' || LENGTH(large_text) || '
}');
```

## 推荐方案选择
- **频繁查询完整内容** → 方案1（分片存储）
- **偶尔访问大内容** → 方案3（S3外部存储）
- **内容可压缩** → 方案4（压缩存储）
- **结构化程度高** → 方案5（分表存储）
