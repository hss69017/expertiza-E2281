class WaitingTeam < ApplicationRecord
  belongs_to :topic, class_name: 'SignUpTopic'
  belongs_to :team, class_name: 'Team'

  validates :topic_id, :team_id, presence: true
  validates :topic_id, uniqueness: { scope: :team_id }

  # The method is used to add team to waitlist table
  def self.add_team_to_topic_waitlist(team_id, topic_id)
    new_waitlist = WaitlistTeam.new
    new_waitlist.topic_id = topic_id
    new_waitlist.team_id = team_id
    if new_waitlist.valid?
      WaitlistTeam.create(topic_id: topic_id, team_id: team_id)
    else
      ExpertizaLogger.info LoggerMessage.new('WaitlistTeam', user_id, "Team #{team_id} cannot be added to waitlist for the topic #{topic_id}")
      ExpertizaLogger.info LoggerMessage.new('WaitlistTeam', user_id, new_waitlist.errors.full_messages.join(" "))
      return false
    end
    return true
  end

  # This method removes team in the waitlist_teams table
  def self.remove_team_from_topic_waitlist(team_id, topic_id)
    waitlisted_team_for_topic = WaitlistTeam.find_by(topic_id: topic_id, team_id: team_id)
    unless waitlisted_team_for_topic.nil?
      waitlisted_team_for_topic.destroy
    else
      ExpertizaLogger.info LoggerMessage.new('WaitlistTeam', user_id, "Cannot find Team #{team_id} in waitlist for the topic #{topic_id} to be deleted.")
    end
    return true
  end

end