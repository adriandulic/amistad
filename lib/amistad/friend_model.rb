module Amistad
  module FriendModel
    def self.included(receiver)
      receiver.class_exec do
        include InstanceMethods

        has_many  :friendships

        has_many  :pending_invited,
                  :through => :friendships,
                  :source => :friend,
                  :conditions => { :'friendships.pending' => true, :'friendships.blocked' => false }

        has_many  :invited,
                  :through => :friendships,
                  :source => :friend,
                  :conditions => { :'friendships.pending' => false, :'friendships.blocked' => false }

        has_many  :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"

        has_many  :pending_invited_by,
                  :through => :inverse_friendships,
                  :source => :user,
                  :conditions => { :'friendships.pending' => true, :'friendships.blocked' => false }

        has_many  :invited_by,
                  :through => :inverse_friendships,
                  :source => :user,
                  :conditions => { :'friendships.pending' => false, :'friendships.blocked' => false }

        has_many  :blocked,
                  :through => :inverse_friendships,
                  :source => :user,
                  :conditions => { :'friendships.blocked' => true }
      end
    end

    module InstanceMethods
      # suggest a user to become a friend. If the operation succeeds, the method returns true, else false
      def invite(user)
        return false if user == self || find_any_friendship_with(user)
        Friendship.new(:user_id => self.id, :friend_id => user.id).save
      end

      # approve a friendship invitation. If the operation succeeds, the method returns true, else false
      def approve(user)
        friendship = find_any_friendship_with(user)
        return false if friendship.nil? || invited?(user)
        friendship.update_attribute(:pending, false)
      end

      # returns the list of approved friends
      def friends
        self.invited(true) + self.invited_by(true)
      end

      # blocks a friendship request
      def block(user)
        friendship = find_any_friendship_with(user)
        return false if friendship.nil? || friendship.blocked? || (friendship.user == self && friendship.pending?)
        friendship.update_attribute(:blocked, true)
      end

      # unblocks a friendship
      def unblock(user)
        friendship = find_any_friendship_with(user)
        return false if friendship.nil? || !friendship.blocked? || friendship.user == self
        friendship.update_attribute(:blocked, false)
      end

      # deletes a friendship
      def remove(user)
        friendship = find_any_friendship_with(user)
        return false if friendship.nil?
        friendship.destroy && friendship.destroyed?
      end

      # checks if a user is a friend
      def friend_with?(user)
        friends.include?(user)
      end

      def connected_with?(user)
        !find_any_friendship_with(user).nil?
      end

      # checks if a user send a friendship's invitation
      def invited_by?(user)
        friendship = find_any_friendship_with(user)
        return false if friendship.nil?
        friendship.user == user
      end

      def invited?(user)
        friendship = find_any_friendship_with(user)
        return false if friendship.nil?
        friendship.friend == user
      end

      # return the list of the ones among its friends which are also friend with the given use
      def common_friends_with(user)
        self.friends & user.friends
      end

      private

        def find_any_friendship_with(user)
          friendship = Friendship.where(:user_id => self.id, :friend_id => user.id).first
          if friendship.nil?
            friendship = Friendship.where(:user_id => user.id, :friend_id => self.id).first
          end
          friendship
        end
    end    
  end
end
