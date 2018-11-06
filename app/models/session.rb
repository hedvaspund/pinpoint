class Session < ActiveRecord::Base

  def self.find_session(session_id)
    ActiveRecord::Base.establish_connection(db_configuration["development"])
    find_by_session_id(session_id)    
  end

  def self.set_session_id(user_id, username)
    session_id = Digest::SHA1.base64digest([user_id, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"].join)      
    serialized_hash = Marshal.dump({current_user_id: user_id, username: username})
    crypt = ActiveSupport::MessageEncryptor.new("258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
    crypted_string = crypt.encrypt_and_sign(serialized_hash)
    find_session(session_id) || create(session_id: session_id, data: crypted_string)
  end

  def self.db_configuration #TBD : move to initializer
    db_configuration_file = File.join(File.expand_path('..', __FILE__), '../..', 'db', 'config.yml')
    YAML.load(File.read(db_configuration_file))
  end

  private

  def self.find_by_session_id(session_id)
    where(session_id: session_id).first
  end


end