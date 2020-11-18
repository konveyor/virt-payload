FROM registry.access.redhat.com/ubi8/ruby-26
ADD payload_writer .
ENTRYPOINT ["bundle", "exec", "ruby",  "payload_writer.rb"]
