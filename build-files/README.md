# SSL Certificate Guide

Nexus Repository Manager3 使用 SSL 憑證的相關設定

## Configuration

* jetty-https.xml
* nexus.properties
* 授權憑證 (`使用 jks 格式`)

指定路徑下的擋案位置實際和 Dockerfile 中 `COPY` 的目地端位置相呼應

## jetty-https.xml

調整帶有註解 `<!-- Need Config -->` 的 value

## nexus.properties

調整 # Jetty section 內的 Property

* 指定的 http, https port
* jetty-https.xml 的路徑位置

## Reference Link

* [SSL Certificate Guide](https://support.sonatype.com/hc/en-us/articles/213465768-SSL-Certificate-Guide?_ga=2.65572654.1009401491.1625573486-1670601112.1625573486) by Peter Lynch

**Enjoy!**
