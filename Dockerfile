# Package mvn stage
FROM maven:3-jdk-11-slim AS build
COPY onfhir-common /home/app/onfhir-common
COPY onfhir-core /home/app/onfhir-core
COPY onfhir-kafka /home/app/onfhir-kafka
COPY onfhir-operations /home/app/onfhir-operations
COPY onfhir-path /home/app/onfhir-path
COPY onfhir-server-r4 /home/app/onfhir-server-r4
COPY onfhir-server-r5 /home/app/onfhir-server-r5
COPY onfhir-server-stu3 /home/app/onfhir-server-stu3
COPY onfhir-validation /home/app/onfhir-validation
COPY pom.xml /home/app
RUN mvn -B -f /home/app/pom.xml clean package



# Get common-data-model config
FROM debian:stable-slim AS config
RUN apt-get -y update && apt-get -y install git
RUN git clone https://github.com/fair4health/common-data-model
# RUN sed -ir "s/8282/8080/g" common-data-model/onfhir.io/fair4health.conf
# RUN sed -ir "s/conf\//\/fhir\/conf\//g" common-data-model/onfhir.io/fair4health.conf
# RUN sed -ir "s/27018/27017/g" common-data-model/onfhir.io/fair4health.conf



FROM openjdk:11
RUN mkdir -p /onfhir

COPY --from=build /home/app/onfhir-server-r4/target/onfhir-server-standalone.jar /fhir/
COPY --from=config /common-data-model/onfhir.io/conf /fhir/conf
COPY --from=config /common-data-model/onfhir.io/fair4health.conf /fhir/

COPY ./conf/profile/* /fhir/conf/profile/
COPY ./conf/codesystem/* /fhir/conf/codesystem/
COPY ./conf/valueset/* /fhir/conf/valueset/
COPY conformance.json /fhir/conf/
COPY mii.conf /fhir/

ADD docker-entrypoint.sh /onfhir

RUN chown root:root /onfhir/docker-entrypoint.sh
RUN chmod +x /onfhir/docker-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/onfhir/docker-entrypoint.sh"]
