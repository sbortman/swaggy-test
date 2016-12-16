Step 1:  Build jar -  ./gradlew assemble
Step 2:  Build image - docker build -t swaggy-test:latest .
Step 3:  Run images - docker run --rm -p 8080:8080 swaggy-test
