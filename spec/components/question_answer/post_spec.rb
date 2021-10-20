# frozen_string_literal: true

require 'rails_helper'

describe QuestionAnswer::PostExtension do
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }
  fab!(:user3) { Fabricate(:user) }
  fab!(:post) { Fabricate(:post_with_long_raw_content) }
  let(:up) { QuestionAnswer::Vote::UP }
  let(:create) { QuestionAnswer::Vote::CREATE }
  let(:destroy) { QuestionAnswer::Vote::DESTROY }
  let(:users) { [user1, user2, user3] }
  let(:vote) do
    ->(user) do
      QuestionAnswer::Vote.vote(post, user, { direction: up, action: create })
    end
  end
  let(:undo_vote) do
    ->(user) do
      QuestionAnswer::Vote.vote(post, user, { direction: up, action: destroy })
    end
  end

  it('should ignore vote_count') do
    expect(Post.ignored_columns.include?("vote_count")).to eq(true)
  end

  it 'should return the post vote count correctly' do
    # no one voted
    expect(post.qa_vote_count).to eq(0)

    users.each do |u|
      vote.call(u)
    end

    expect(post.qa_vote_count).to eq(users.size)

    users.each do |u|
      undo_vote.call(u)
    end

    expect(post.qa_vote_count).to eq(0)
  end

  it 'should return last voted correctly' do
    freeze_time do
      expect(post.qa_last_voted(user1.id)).to eq(nil)

      vote.call(user1)

      expect(post.qa_last_voted(user1.id)).to eq_time(Time.zone.now)
    end
  end

  it 'should return qa_can_vote correctly' do
    expect(post.qa_can_vote(user1.id)).to eq(true)

    vote.call(user1)

    expect(post.qa_can_vote(user1.id)).to eq(false)

    SiteSetting.qa_tl_allow_multiple_votes_per_post = true

    expect(post.qa_can_vote(user1.id)).to eq(true)
  end
end
