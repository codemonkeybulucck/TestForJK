#!/bin/sh

curl --location --request POST '10.21.47.217:8090/md/cgi/v1/real-time-message/actions/batch-push' \
--header 'Content-Type: application/json' \
--header 'x-apm-traceid: 2f2a4e045f1e48d784dd1323e294f90c' \
--data '[{
   "messageId":"d2a45e68-7c89-45fb-a7cc-ba377bf07c13",
   "correlationId":"d2a45e68-7c89-45fb-a7cc-ba377bf07c2a",
   "topic":"signature.start",
   "system":"dualrecord",
   "type":0,
   "domain":"finance",
   "contentType":"application/json",
   "contentEncoding":"utf-8",
   "version":1,
   "namespace":"finance_dualrecord_v1",
   "policy":1,
   "endpointIds":["mobile/04c2e160-5276-44e3-a61b-8c3c0bc6a027"],
   "traceId":"2F2A4E045F1E48D784DD1323E294F90D",
   "timestamp":1581133991695,
   "body":"{\"roomEndpointId\":\"11caf9ed-f24f-4bc3-98f9-93ab36c9ae28\"}",
   "description":"取消静音"
}]'