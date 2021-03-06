# Copyright 2015 Square Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

TOUCHDOWN_BRANCH_KEY = 'shuttle_settings:touchdown_running'

namespace :touchdown do
  desc "Updates touchdown branches"
  task update: :environment do
    start_time = Time.now
    Rails.logger.info "[touchdown:update] Attempting to run touchdown branch updater."

    # only run one instance of this cron
    if Shuttle::Redis.exists(TOUCHDOWN_BRANCH_KEY)
      Rails.logger.info "[touchdown:update] Unable to obtain lock."
      exit
    end

    Shuttle::Redis.setex TOUCHDOWN_BRANCH_KEY, 1.hour, '1'
    Rails.logger.info "[touchdown:update] Successfully obtained lock.  Updating touchdown branch."

    Project.git.each do |project|
      begin
        project_start_time = Time.now
        Rails.logger.info "[touchdown:update] Starting update for project #{project.name}."
        TouchdownBranchUpdater.new(project).update
        Rails.logger.info "[touchdown:update] Successfully updated touchdown branch for project #{project.name}.  Took #{(Time.now - project_start_time).round} seconds."
      rescue StandardError => e
        Rails.logger.error "[touchdown:update] Failed to update touchdown branch for project #{project.name}."
        Rails.logger.error(e)
      end
    end

    Shuttle::Redis.del TOUCHDOWN_BRANCH_KEY
    Rails.logger.info "[touchdown:update] Releasing lock.  Successfully updated touchdown branch. Took #{(Time.now - start_time).round} seconds."
  end
end
