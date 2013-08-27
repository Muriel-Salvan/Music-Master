# encoding: UTF-8

require 'yaml'
require 'digest/md5'

class Hash

  # Get a unique ID that will always be the same for any Hash having the same content
  #
  # Return::
  # * _String_: The unique ID
  def unique_id
    return Digest::MD5.hexdigest(self.to_a.sort.to_yaml)
  end

end
