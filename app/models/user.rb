require 'bcrypt'
require_relative './account'
require_relative './session'


class User < ActiveRecord::Base
  validates :username, presence: true, :uniqueness => true, :length => { :in => 3..20 }
  validates :password, presence: true

  before_save :encrypt_password
	after_save :clear_password

  has_one :account

  attr_accessor :password

  def encrypt_password
    if password.present?
      self.username = username
      self.salt = BCrypt::Engine.generate_salt
      self.encrypted_password = BCrypt::Engine.hash_secret(password, salt)
    end
  end

  def clear_password
    self.password = nil
  end

  def self.authenticate!(username, password)
    return false unless [username, password].all?
    ActiveRecord::Base.establish_connection(db_configuration["development"])
    user = where(username: username).last
    return false unless user
    salt = user.salt
    password = BCrypt::Engine.hash_secret(password, salt)
    authenticated = compare(user.encrypted_password, password)
    if authenticated
      session_id = Session.set_session_id(user.id, username).session_id
      { username: user.username, account_status: user.account.amount, status: authenticated, session_id: session_id }
    else
      { username: user.username, status: authenticated}
    end
  end

  def self.load_from_data(crypted_string)
    crypt = ActiveSupport::MessageEncryptor.new("258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
    result = crypt.decrypt_and_verify(crypted_string)
    data = Marshal.load(result)
    User.find(data[:current_user_id])
  end

  def self.logout!(session_id)
    session = Session.find_session(session_id)
    session.session_id = nil
    session.save
    {status: true}
  end

  def self.db_configuration #TBD : move to initializer
    db_configuration_file = File.join(File.expand_path('..', __FILE__), '../..', 'db', 'config.yml')
    YAML.load(File.read(db_configuration_file))
  end

  def as_json(options={})
    super(:only => [:username],
          :include => {
            :account => {:only => [:amount]}
          }
    )
  end

  private

  def self.compare(hashed_password, password)
    return false if hashed_password.blank?
    secure_compare(hashed_password, password)
  end

  def self.secure_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"

    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == 0
  end
end