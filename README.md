Steps:

1.  Build jar -  `./gradlew assemble`
2.  Build image - `docker build -t swaggy-test:latest .`
3.  Run images - `docker run --rm -p 8080:8080 swaggy-test`
