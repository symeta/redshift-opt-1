# redshift-opt-1
（以下优化建议涉及的脚本/代码只为示例，如使用需要请根据对应的语法和业务场景进行调试和测试。）

## 使用redshift遇到超长字符串兼容问题，即使使用super仍然会有这个问题，比如json的value超过65535不可用。解决这个问题有什么建议么？

[Redshift Super Type Limitations](https://docs.aws.amazon.com/redshift/latest/dg/limitations-super.html)

## 优化建议：
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
 a. 原始数据
```txt
large_text = "x" * 100000  # 超过65535字节
```
 b. 分片处理
```json
chunked_data = {
    "metadata": {"total_chunks": 2, "original_length": len(large_text)},
    "content": split_large_string(large_text)
}
```
 c. 插入Redshift
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

# Redshift中的python udf函数从11月1日开始停止支持，有什么替代方案么？

- [Redshift Python UDF](https://docs.aws.amazon.com/redshift/latest/dg/user-defined-functions.html)
- [The BLog](https://aws.amazon.com/cn/blogs/big-data/amazon-redshift-python-user-defined-functions-will-reach-end-of-support-after-june-30-2026/)

**2025年11月1日之前创建的Python UDF还可以继续使用**

几个替代方向：
## 1. SQL UDF（推荐）
用纯SQL重写逻辑，性能最佳：
- 替代Python字符串处理

```sql
CREATE OR REPLACE FUNCTION clean_phone(phone VARCHAR(50))
RETURNS VARCHAR(50)
STABLE
AS $$
  SELECT REGEXP_REPLACE(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), '^1', '')
$$;
```
- 替代Python数学计算
```sql
CREATE OR REPLACE FUNCTION calculate_score(base_score INT, multiplier DECIMAL)
RETURNS DECIMAL
IMMUTABLE
AS $$
  SELECT CASE 
    WHEN base_score IS NULL THEN 0
    ELSE base_score * COALESCE(multiplier, 1.0)
  END
$$;
```
## 2. Lambda UDF
对于复杂逻辑，使用Lambda函数：
- 创建Lambda UDF

```sql
CREATE OR REPLACE EXTERNAL FUNCTION process_json(input VARCHAR(MAX))
RETURNS VARCHAR(MAX)
STABLE
LAMBDA 'arn:aws:lambda:us-east-1:123456789012:function:redshift-json-processor';
```

- 使用Lambda UDF
```sql
SELECT id, process_json(raw_data) as processed_data
FROM my_table;
```

Lambda函数示例（Python）：
```python
import json

def lambda_handler(event, context):
    results = []
    for record in event['arguments']:
        input_data = record[0]
        # 处理逻辑
        processed = json.loads(input_data)
        processed['timestamp'] = int(time.time())
        results.append(json.dumps(processed))
    
    return {'results': results}
```

## 3. 预处理数据
在ETL阶段处理数据：
```python
# 使用pandas/boto3预处理
import pandas as pd
import boto3

def preprocess_data():
    # 从S3读取原始数据
    df = pd.read_csv('s3://bucket/raw-data.csv')
    
    # 应用复杂逻辑
    df['processed_field'] = df['raw_field'].apply(complex_function)
    
    # 写回S3
    df.to_csv('s3://bucket/processed-data.csv', index=False)
    
    # 使用COPY命令加载到Redshift
```

## 4. 存储过程
对于复杂的批处理逻辑：
```sql
CREATE OR REPLACE PROCEDURE batch_process()
LANGUAGE plpgsql
AS $$
BEGIN
    -- 复杂的数据处理逻辑
    UPDATE target_table 
    SET processed_field = CASE 
        WHEN condition1 THEN value1
        WHEN condition2 THEN value2
        ELSE default_value
    END;
    
    COMMIT;
END;
$$;
```

# Redshift中的宽表（超过200字段的表）从s3中copy写入redshift时缓慢，有什么优化方向么？

针对Redshift宽表COPY性能问题，有以下优化方向：

## 1. 文件格式优化

- 使用Parquet格式（推荐）
```sql
COPY wide_table FROM 's3://bucket/data/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
FORMAT AS PARQUET;
```
- 使用压缩的分隔符文件
```sql
COPY wide_table FROM 's3://bucket/data/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
DELIMITER '|'
GZIP;
```

## 2. 并行度优化

- 确保文件数量是slice数量的倍数
- 例如：8个slice的集群，使用8/16/32个文件
- 使用manifest文件控制并行度
```sql
COPY wide_table FROM 's3://bucket/manifest.json'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
MANIFEST;
```

## 3. 表设计优化

- 选择合适的分布键和排序键
```sql
CREATE TABLE wide_table (
    id BIGINT DISTKEY,
    timestamp TIMESTAMP SORTKEY,
    col1 VARCHAR(50),
    col2 INTEGER,
    -- ... 其他字段
) 
DISTSTYLE KEY;
```

- 考虑列式压缩
```sql
ALTER TABLE wide_table ALTER COLUMN text_col ENCODE LZO;
ALTER TABLE wide_table ALTER COLUMN int_col ENCODE DELTA;
```

## 4. COPY参数优化

```sql
COPY wide_table FROM 's3://bucket/data/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
FORMAT AS PARQUET
COMPUPDATE OFF          -- 跳过压缩分析
STATUPDATE OFF          -- 跳过统计信息更新
MAXERROR 1000          -- 允许一定错误
ACCEPTINVCHARS         -- 处理无效字符
TRUNCATECOLUMNS;       -- 截断超长字段
```

## 5. 分批加载策略

```sql
# 分批处理大文件
import boto3

def split_and_load():
    # 按时间或大小分割数据
    for batch in data_batches:
        copy_sql = f"""
        COPY wide_table FROM 's3://bucket/batch_{batch}/'
        IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
        FORMAT AS PARQUET;
        """
        execute_sql(copy_sql)
```

## 6. 预处理优化

- 使用临时表先加载，再转换
```sql
CREATE TEMP TABLE staging_table (LIKE wide_table);

COPY staging_table FROM 's3://bucket/data/'
IAM_ROLE 'arn:aws:iam::account:role/RedshiftRole'
FORMAT AS PARQUET;
```
- 批量插入到目标表
```sql
INSERT INTO wide_table 
SELECT * FROM staging_table;
```

## 7. 集群配置优化

• **节点类型**: 使用ra3.xlplus或ra3.4xlarge
• **节点数量**: 确保有足够的slice处理并发
• **WLM配置**: 为COPY操作分配专用队列

- 创建专用WLM队列
- 在参数组中设置：
- wlm_json_configuration = [{"query_group": "copy_queue", "memory_percent": 50, "concurrency": 2}]
```sql
SET query_group TO 'copy_queue';
COPY wide_table FROM 's3://bucket/data/' ...;
```

## 8. 监控和诊断
- 查看COPY性能
```sql
SELECT query, starttime, endtime, 
       DATEDIFF(seconds, starttime, endtime) as duration
FROM stl_query 
WHERE querytxt LIKE 'COPY%'
ORDER BY starttime DESC;
```
- 检查数据倾斜
```sql
SELECT slice, COUNT(*) 
FROM stv_tbl_perm 
WHERE name = 'wide_table'
GROUP BY slice;
```

# 对于一行转多行的场景，有没有什么快捷方式实现？比如a,b,c,d怎么快速根据逗号切分形成一列？

Redshift中实现一行转多行有几种方式：

## 使用SPLIT_TO_ARRAY
```sql
WITH input AS (
    SELECT 1 as id, 'a,b,c,d' as tags
    UNION ALL
    SELECT 2 as id, 'x,y,z' as tags
),
supered as (
select id, split_to_array(tags) as tags from input
)
 
select o1.id, o2 from supered o1, o1.tags o2
```

<img width="904" height="618" alt="Screenshot 2025-09-22 at 17 09 19" src="https://github.com/user-attachments/assets/ee9c209e-9fce-4ada-9181-1abd1f800634" />

## 注意事项
- SPLIT_TO_ARRAY在空字符串时返回包含空字符串的数组
- 使用TRIM()处理多余空格
- 大数据量时考虑先过滤再展开
- 可以与LATERAL子查询结合使用更复杂的逻辑


Option 1: Use the user-accessible equivalent
sql
SELECT * FROM sys_query_history 
WHERE query_type = 'INSERT';


Option 2: Grant superuser privileges to your user
You need to connect as a user with superuser privileges and run:
sql
ALTER USER admin CREATEUSER;


Option 3: Use alternative system tables that don't require superuser
sql
-- For query information
SELECT * FROM stv_recents WHERE status = 'Running' OR status = 'Done';

-- For load information  
SELECT * FROM stl_load_commits;

