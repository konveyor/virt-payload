# virt-payload

Generates a tar.gz payload file that can be uploaded to Xavier/Migration Analytics, with content extracted from the Konveyor provider inventory database. Payload file is returned to the user's browser to save.

Call with a list of provider names to include in the payload file, for example:

http://address\_or\_service:8080/api/v1/extract?providers=test1,test2