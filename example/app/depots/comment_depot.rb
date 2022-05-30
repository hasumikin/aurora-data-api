# frozen_string_literal: true

require_relative '../models/comment'

CommentDepot = AuroraDataApi::Depot[Comment] do
end
