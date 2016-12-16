FROM anapsix/alpine-java
MAINTAINER DoloresAbernathie
COPY build/libs/swaggy-test-0.1.jar /usr/share
EXPOSE 8080
CMD ["java","-jar","/usr/share/swaggy-test-0.1.jar"]
