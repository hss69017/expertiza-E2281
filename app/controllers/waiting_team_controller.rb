class WaitingTeamController < ApplicationController
  include AuthorizationHelper

  # Returns team added to waitlist the earliest
  def first_team_in_waitlist_for_topic(topic_id)
    waitlisted_team_for_topic = WaitlistTeam.where(topic_id: topic_id).order("created_at ASC").first
    waitlisted_team_for_topic
  end

  # Returns FALSE if team belongs to a waitlist
  def team_has_waitlists(team_id)
    WaitlistTeam.where(team_id: team_id).empty?
  end

  # Returns FALSE if topic contains a waitlist
  def topic_has_waitlists(topic_id)
    WaitlistTeam.where(topic_id: topic_id).empty?
  end

  # Deletes all waitlist entries for a team
  def delete_all_waitlists_for_team(team_id)
    waitlisted_topics_for_team = get_all_waitlists_for_team team_id
    if !waitlisted_topics_for_team.nil?
      waitlisted_topics_for_team.destroy_all
    else
      ExpertizaLogger.info LoggerMessage.new('WaitlistTeam', user_id, "Cannot find Team #{team_id} in waitlist.")
      return false
    end
    return true
  end

  # Deletes all entries from a waitlist
  def delete_all_waitlists_for_topic(topic_id)
    waitlisted_teams_for_topic = get_all_waitlists_for_topic topic_id
    if !waitlisted_teams_for_topic.nil?
      waitlisted_teams_for_topic.destroy_all
    else
      ExpertizaLogger.info LoggerMessage.new('WaitlistTeam', user_id, "Cannot find Topic #{topic_id} in waitlist.")
    end
    return true
  end

  # Returns a list of waitlisted topics for a team
  def get_all_waitlists_for_team(team_id)
    WaitlistTeam.joins(:topic).select('waitlist_teams.id, topic_name, team_id, topic_id, created_at').where(team_id: team_id)
  end

  # Returns a list of teams waitlisted for a topic
  def get_all_waitlists_for_topic(topic_id)
    WaitlistTeam.where(topic_id: topic_id)
  end

  # Assigns first team on topics waitlist to topic
  def signup_first_waitlist_team(topic_id)
    sign_up_waitlist_team = nil
    ApplicationRecord.transaction do
      first_waitlist_team = first_team_in_waitlist_for_topic(topic_id)
      unless first_waitlist_team.blank?
        sign_up_waitlist_team = SignedUpTeam.new
        sign_up_waitlist_team.topic_id = first_waitlist_team.topic_id
        sign_up_waitlist_team.team_id = first_waitlist_team.team_id
        if sign_up_waitlist_team.valid?
          sign_up_waitlist_team.save
          first_waitlist_team.destroy
          delete_all_waitlists_for_team sign_up_waitlist_team.team_id
        else
          ExpertizaLogger.info LoggerMessage.new('WaitlistTeam', session[:user].id, "Cannot find Topic #{topic_id} in waitlist.")
          raise ActiveRecord::Rollback
        end
      end
    end
    sign_up_waitlist_team
  end
end
