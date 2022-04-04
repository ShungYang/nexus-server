# Nexus Repository Manager3

使用 Docker 運行 Nexus Repository Manager3

## _About Nexus Repository Manager_

> Single source of truth for all of your components, binaries, and build artifacts.

Nexus is a repository manager. It allows you to proxy, collect, and manage your dependencies so that you are not constantly juggling a collection of JARs. It makes it easy to distribute your software. Internally, you configure your build to publish artifacts to Nexus and they then become available to other developers. You get the benefits of having your own 'central', and there is no easier way to collaborate.

## Benefits

* 可做為軟體開發生命週期中元件及套件的統一來源儲存庫
* 很容易和現有使用者驗證及單點登入等機制做整合 ex. LDAP, SAML/SSO
* [支援現今許多主流的開發語言格式 ex. .NET, Java, Python, JavaScript](https://help.sonatype.com/repomanager3/nexus-repository-administration/formats)

## Sonatype Nexus Installation Using Docker

相對於以往透過安裝包建立的方式, 使用 Docker 運行 Nexus 相當的快速有效率, 特別是在POC 階段想快速的了解系統可支援的程度和使用體驗時特別有幫助, 而且對於日後 Nexus 需要升版時, 只要運行新版 Nexus docker image 掛載原有的 volume 即可快速升級同時保留舊有擋案.

* Official docker image : [sonatype/nexus3](https://hub.docker.com/r/sonatype/nexus3/)
* GitHub 位置 : [sonatype/docker-nexus3](https://github.com/sonatype/docker-nexus3)

下載最新版 nexus3 docker image

```sh
docker pull sonatype/nexus3:latest
```

## Persistent Data

因為我們需要保存 Nexus 相關的設定和上傳的套件, 所以需要將資料儲存下來, 般來說可以再整合外部資料庫, 但由於我們的 Nexus 運行在 docekr conatiner 中, 所以直接參考 [Managing Data in Containers](https://docs.docker.com/engine/tutorials/dockervolumes)

建立一個 `docker volume`, 等一下運行容器時需要進行綁定

```sh
docker volume create --name nexus-data
```

## Running

運行 sonatype/nexus3, 並將 host port 8081 映射到 container port 8081

```sh
docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
```

透過訪問 Nexus Server Webpage 確認是否成功運行, Nexus 被安裝在 conatiner 中的位置 : `/opt/sonatype/nexus`

```sh
curl http://localhost:8081/
```

第一次在新容器啟用服務時大概會花3分鐘左右的時間, 可以透過判斷 log 的方式確認服務是否準備就緒

```sh
docker logs -f nexus
```

停止運行中的 Nexus Server, 並給予 2分鐘的緩衝時間確認所有服務完整停止

```sh
docker stop --time=120 <CONTAINER_NAME>
```

When stopping, be sure to allow sufficient time for the databases to fully shut down.

## Building the Nexus Repository Manager image

一般來說 POC 階段直接使用官方提供的 Nexus docker image 即可, 當我們決定要將 Nexus Server go Production 時, 肯定需要做優化, ex 如果要做為 docker registry 那就要求連線走 https 443 port, 所以我們必須將 SSL 憑證也一起打包 build 屬於我們自己的 docker image.

我們使用打包憑證的 [Dockerfile](https://github.com/ShungYang/nexus-server/blob/master/Dockerfile), 指令內容如下

* `FROM` 選擇一個 /sonatype/nexus3 版本做基底 image
* `LABEL` 標籤這個 Image
* `EXPOSE` 聲明映射的 port
* `COPY` 將 build-files 中的 configuration 複製到 Container 的指定路徑下, [具體說明](https://github.com/ShungYang/nexus-server/blob/master/build-files/README.md)

```sh
docker build -t my-nexus3:demo . --no-cache
```

## Publish to Nexus docker registry

既然我們已經架設好了 Nexus, 那可以拿來作為 Private Docker Registry:

* [Docker Registry](https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/docker-registry)
* [SSL and Repository Connector Configuration](https://help.sonatype.com/repomanager3/nexus-repository-administration/formats/docker-registry/ssl-and-repository-connector-configuration)

設定好 docker-hosted registry 後, 使用以下的指令作發布.

```sh
docker login -u {USER-NAME} -p {USER-PASSWORD} {HOST-DOMAIN}:{DOCKER-REGISTRY-PORT}/repository/docker-hosted-demo/
docker tag my-nexus3:demo {HOST-DOMAIN}:{DOCKER-REGISTRY-PORT}/my-nexus3:demo
docker push {HOST-DOMAIN}:{DOCKER-REGISTRY-PORT}/my-nexus3:demo
```

試著是否能成功 Pull

```sh
docker login -u {USER-NAME} -p {USER-PASSWORD} {HOST-DOMAIN}:{DOCKER-REGISTRY-PORT}/repository/docker-group-demo/
docker pull {HOST-DOMAIN}:{DOCKER-REGISTRY-PORT}/my-nexus3:demo
```

Note. `在規劃 Nexus 時通常會把 push / pull 設計為不同的儲存庫, 所以 regisrty port 會不同`

## Reference Link

* [Sonatype Nexus Installation Using Docker](https://blog.sonatype.com/sonatype-nexus-installation-using-docker) by Rajesh Kumar

**Enjoy!**
