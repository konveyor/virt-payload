FROM registry.access.redhat.com/ubi8/ruby-26

ADD payload_writer .

RUN gem install tempfile --source 'https://rubygems.org/' && \
    gem install rest-client --source 'https://rubygems.org/' && \
    gem install sinatra --source 'https://rubygems.org/' && \
    gem install sinatra-namespace --source 'https://rubygems.org/' && \
    gem install package --source 'https://rubygems.org/' && \
    gem install memory_profiler --source 'https://rubygems.org/'

CMD ruby payload_writer.rb
