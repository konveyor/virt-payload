registry.access.redhat.com/ubi8/ruby-26
ADD payload_writer .
RUN gem install tempfile --source 'https://rubygems.org/'
RUN gem install rest-client --source 'https://rubygems.org/'
RUN gem install sinatra --source 'https://rubygems.org/'
RUN gem install sinatra-namespace --source 'https://rubygems.org/'
RUN gem install package --source 'https://rubygems.org/'
CMD ruby payload_writer.rb
