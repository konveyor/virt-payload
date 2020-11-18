FROM registry.access.redhat.com/ubi8/ruby-26
RUN gem install \
        memory_profiler \
        package \
        rest-client \
        sinatra \
        sinatra-namespace \
        tempfile \
        --source 'https://rubygems.org/' \
        --no-document
ADD payload_writer .
CMD ruby payload_writer.rb
