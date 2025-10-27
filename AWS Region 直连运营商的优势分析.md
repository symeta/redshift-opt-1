

# AWS Region 直连运营商的优势分析



## 1、雅加达Region

#### 1.1 雅加达Region Peer运营商统计

| Category      | Count | Providers                                                    |
| ------------- | ----- | ------------------------------------------------------------ |
| **ISP**       | 22    | Biznet Networks, CBN Internet, CBN Networks, Data Buana Nusantara, FiberStar, First Media, Herza Digital Indonesia, Indosat Ooredoo, Lintasarta, Media Cepat Indonesia, MITRA TELEMEDIA MANUNGGAL, MITRA VISIONER PRATAMA, Moratel, MyRepublic ID, PT Jala Lintas Media, PT Jembatan Citra Nusantara, PT PGAS TELEKOMUNIKASI, PT Smartfren, PT. XL AXIATA, Telekomunikasi Indonesia International, Telin, telkomsel |
| **IX Peer**   | 4     | DCI Indonesia, Digital Edge EPIX Jakarta, IIX Jakarta, JKT IX |
| **Cloud/CDN** | 3     | Akamai, Cloudflare, Zenlayer                                 |
| **DC/Infra**  | 1     | iForte Solusi Infotek - eXchange                             |
| **Satellite** | 1     | PT Starlink Services Indonesia                               |
| **总计**      | 31    |                                                              |



#### 1.2 AWS 雅加达Region与运营商间连接具有更广泛高性能直接连接，实现更为广泛的高性能网络覆盖

1. **对接运营商**：通过专线直接对接（Private Peering），为用户实现**经运营商一跳直达公有云**（用户 → ISP → AWS） 

   - **华为云**：直接对接 **6 家运营商**（Telkom、Telkomsel、Indosat、Moratelindo、TRI、XL）

   - **AWS**：

     - 直接对接 **22 家 ISP 运营商**，覆盖印尼全部主流运营商及区域性运营商，不仅覆盖华为提到的所有 Top 运营商（Telkom、Telkomsel、Indosat、XL、Moratel），还额外直连了 **16 家其他运营商**，包括新兴运营商如 **MyRepublic ID**、**Biznet Networks**、**First Media** 等，确保用户无论使用哪家运营商都能获得最优体验；
     - 直接对接 **1家卫星通信提供商PT Starlink Services Indonesia**，通过星链服务覆盖印尼偏远岛屿和海域，为全国性业务提供无死角覆盖；
     - 直接对接**1家印尼大型数据中心互联服务商 iForte Solusi Infotek - eXchange**，支持企业混合云场景的低延时接入
     - 直接对接**3家网络和CDN厂商**（**Cloudflare、Akamai、Zenlayer**），覆盖更广泛的低延时场景

     

2. **对接IXP（互联网交换中心）** ：为其它用户实现**经IXP中转多跳**到达公有云（：**用户 → ISP → IXP → AWS**）
   * 华为云：对接**2个IXP**：IIX、OPENIX
   * AWS： 对接 **4 个IXP**：IIX Jakarta、JKT IX、DCI Indonesia、Digital Edge EPIX Jakarta





### 

## 2、墨西哥Region

### 2.1 墨西哥Region Peer运营商统计

| Category      | Count | Providers                                                    |
| ------------- | ----- | ------------------------------------------------------------ |
| **ISP**       | 17    | Alestra, IENTC Telecom, Megacable (2), TransTelco, ATT, Marcatel, Telmex, Totalplay, izzi, Sosigma, RedUno, WIGO, Level3, Bestel, Internet Michoacan, PCCW |
| **Cloud/CDN** | 3     | Google, Cloudflare, Zenlayer                                 |
| **IX Peer**   | 2     | PIT MX Region, DE-CIX Querétaro                              |
| **DC/Infra**  | 1     | American Tower Mexico                                        |
| **Satellite** | 1     | SpaceX Starlink                                              |
| **TOTAL**     | 24    |                                                              |