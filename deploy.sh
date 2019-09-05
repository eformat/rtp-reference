#!/bin/bash

bootstrap=`oc get service rtp-demo-cluster-kafka-bootstrap -o=jsonpath='{.spec.clusterIP}{"\n"}'`
bootstrap="${bootstrap}:9092"
database_url=`oc get service mysql-56-rhel7 -o=jsonpath='{.spec.clusterIP}{"\n"}'`
database_url="jdbc:mysql://${database_url}:3306/rtpdb"

mvn clean install

cd rtp-debtor-payment-service
oc create configmap rtp-debtor-payment-service-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=PRODUCER_TOPIC=debtor-payments \
            --from-literal=SECURITY_PROTOCOL=PLAINTEXT \
            --from-literal=SERIALIZER_CLASS=rtp.demo.debtor.domain.model.payment.serde.PaymentSerializer \
            --from-literal=ACKS=1 \
            --from-literal=DATABASE_URL="${database_url}" \
            --from-literal=DATABASE_USER=dbuser \
            --from-literal=DATABASE_PASS=dbpass
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-payment-service --from configmap/rtp-debtor-payment-service-config
cd ..

cd rtp-debtor-send-payment
oc create configmap rtp-debtor-send-payment-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=DEBTOR_PAYMENTS_TOPIC=debtor-payments \
            --from-literal=MOCK_RTP_CREDIT_TRANSFER_TOPIC=mock-rtp-debtor-credit-transfer \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-debtor-send-payment \
            --from-literal=DESERIALIZER_CLASS=rtp.demo.debtor.domain.model.payment.serde.PaymentDeserializer \
            --from-literal=SERIALIZER_CLASS=rtp.message.model.serde.FIToFICustomerCreditTransferV06Serializer \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-send-payment --from configmap/rtp-debtor-send-payment-config
cd ..

cd rtp-mock
oc create configmap rtp-mock-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDIT_TRANS_DEBTOR_TOPIC=mock-rtp-debtor-credit-transfer \
            --from-literal=CREDIT_TRANS_CREDITOR_TOPIC=mock-rtp-creditor-credit-transfer \
            --from-literal=CREDITOR_ACK_TOPIC=mock-rtp-creditor-acknowledgement \
            --from-literal=DEBTOR_CONFIRMATION_TOPIC=mock-rtp-debtor-confirmation \
            --from-literal=CREDITOR_CONFIRMATION_TOPIC=mock-rtp-creditor-confirmation \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-mock \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-demo-mock --from configmap/rtp-mock-config
cd ..

cd rtp-creditor-receive-payment
oc create configmap rtp-creditor-receive-payment-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDIT_TRANS_CREDITOR_TOPIC=mock-rtp-creditor-credit-transfer \
            --from-literal=CREDITOR_PAYMENTS_TOPIC=creditor-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-creditor-receive-payment \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-receive-payment --from configmap/rtp-creditor-receive-payment-config
cd ..

cd rtp-creditor-payment-acknowledgement
oc create configmap rtp-creditor-payment-acknowledgement-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_PAYMENTS_TOPIC=creditor-payments \
            --from-literal=MOCK_RTP_CREDITOR_ACK_TOPIC=mock-rtp-creditor-acknowledgement \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-creditor-payment-acknowledgement \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-payment-acknowledgement --from configmap/rtp-creditor-payment-acknowledgement-config
cd ..

cd rtp-creditor-payment-confirmation
oc create configmap rtp-creditor-payment-confirmation-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_CONFIRMATION_TOPIC=creditor-payment-confirmation \
            --from-literal=MOCK_RTP_CREDITOR_CONFIRMATION_TOPIC=mock-rtp-creditor-confirmation \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-creditor-payment-confirmation \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-payment-confirmation --from configmap/rtp-creditor-payment-confirmation-config
cd ..

cd rtp-creditor-complete-payment
oc create configmap rtp-creditor-complete-payment-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=creditor-completed-payments \
            --from-literal=CREDITOR_PAYMENTS_TOPIC=creditor-payments \
            --from-literal=CREDITOR_CONFIRMATION_TOPIC=creditor-payment-confirmation \
            --from-literal=APPLICATION_ID=creditor-complete-payment \
            --from-literal=CLIENT_ID=creditor-complete-payment-client \
            --from-literal=DATABASE_URL="${database_url}" \
            --from-literal=DATABASE_USER=dbuser \
            --from-literal=DATABASE_PASS=dbpass
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-complete-payment --from configmap/rtp-creditor-complete-payment-config
cd ..

cd rtp-creditor-customer-notification
oc create configmap rtp-creditor-customer-notification-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=creditor-completed-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-creditor-customer-notification \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-customer-notification --from configmap/rtp-creditor-customer-notification-config
cd ..

cd rtp-creditor-core-banking
oc create configmap rtp-creditor-core-banking-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=creditor-completed-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-creditor-core-banking \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-core-banking --from configmap/rtp-creditor-core-banking-config
cd ..

cd rtp-creditor-auditing
oc create configmap rtp-creditor-auditing-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=creditor-completed-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-creditor-auditing \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-creditor-auditing --from configmap/rtp-creditor-auditing-config
cd ..

cd rtp-debtor-payment-confirmation
oc create configmap rtp-debtor-payment-confirmation-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=DEBTOR_CONFIRMATION_TOPIC=debtor-payment-confirmation \
            --from-literal=MOCK_RTP_DEBTOR_CONFIRMATION_TOPIC=mock-rtp-debtor-confirmation \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-debtor-payment-confirmation \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-payment-confirmation --from configmap/rtp-debtor-payment-confirmation-config
cd ..

cd rtp-debtor-complete-payment
oc create configmap rtp-debtor-complete-payment-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=DEBTOR_COMPLETED_PAYMENTS_TOPIC=debtor-completed-payments \
            --from-literal=DEBTOR_PAYMENTS_TOPIC=debtor-payments \
            --from-literal=DEBTOR_CONFIRMATION_TOPIC=debtor-payment-confirmation \
            --from-literal=APPLICATION_ID=debtor-complete-payment \
            --from-literal=CLIENT_ID=debtor-complete-payment-client \
            --from-literal=DATABASE_URL="${database_url}" \
            --from-literal=DATABASE_USER=dbuser \
            --from-literal=DATABASE_PASS=dbpass
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-complete-payment --from configmap/rtp-debtor-complete-payment-config
cd ..

cd rtp-debtor-customer-notification
oc create configmap rtp-debtor-customer-notification-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=debtor-completed-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-debtor-customer-notification \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-customer-notification --from configmap/rtp-debtor-customer-notification-config
cd ..

cd rtp-debtor-core-banking
oc create configmap rtp-debtor-core-banking-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=debtor-completed-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-debtor-core-banking \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-core-banking --from configmap/rtp-debtor-core-banking-config
cd ..

cd rtp-debtor-auditing
oc create configmap rtp-debtor-auditing-config \
            --from-literal=BOOTSTRAP_SERVERS="${bootstrap}" \
            --from-literal=CREDITOR_COMPLETED_PAYMENTS_TOPIC=debtor-completed-payments \
            --from-literal=CONSUMER_MAX_POLL_RECORDS=500 \
            --from-literal=CONSUMER_COUNT=1 \
            --from-literal=CONSUMER_SEEK_TO=end \
            --from-literal=CONSUMER_GROUP=rtp-debtor-auditing \
            --from-literal=ACKS=1
mvn fabric8:deploy -Popenshift
oc set env dc/rtp-debtor-auditing --from configmap/rtp-debtor-auditing-config
cd ..
