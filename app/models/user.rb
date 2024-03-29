class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :links, dependent: :destroy

  has_one_attached :content

  extend FriendlyId
  friendly_id :username, use: :slugged

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9]+\z/ },
            length: { minimum: 3, maximum: 20 }

  validate :username_not_reserved
  validate :email_not_reserved

  attr_writer :login

  def login
    @login || username || email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  private

  RESERVED_WORDS = %w[
    admin analytics appearance settings up users health rails
  ].freeze

  def username_not_reserved
    return unless RESERVED_WORDS.include?(username)

    errors.add(:username, 'is reserved and cannot be used')
  end

  def email_not_reserved
    return unless RESERVED_WORDS.any? { |word| email.include?(word) }

    errors.add(:email, 'contains a reserved word')
  end
end
