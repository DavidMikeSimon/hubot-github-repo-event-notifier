#! /usr/bin/env coffee

unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

extractMentionsFromBody = (body) ->
  mentioned = body.match(/(^|\s)(@[\w\-\/]+)/g)

  if mentioned?
    mentioned = mentioned.filter (nick) ->
      slashes = nick.match(/\//g)
      slashes is null or slashes.length < 2

    mentioned = mentioned.map (nick) -> nick.trim()
    mentioned = unique mentioned

    "\nMentioned: #{mentioned.join(", ")}"
  else
    ""

buildNewIssueOrPRMessage = (data, eventType, callback) ->
  pr_or_issue = data[eventType]
  return unless pr_or_issue.body?

  switch data.action
    when "opened"
      actionMsg = "New"
    when "reopened"
      actionMsg = "Reopened"
    when "closed"
      actionMsg = "Closed"
    else return

  mentioned_line = ''
  mentioned_line = extractMentionsFromBody(pr_or_issue.body)
  callback "#{actionMsg} #{eventType.replace('_', ' ')} \"#{pr_or_issue.title}\" by #{pr_or_issue.user.login}: #{pr_or_issue.html_url}#{mentioned_line}"

module.exports =
  issues: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'issue', callback)

  issue_comment: (data, callback) ->
    callback "#{data.comment.user.login} commented on an issue: #{data.comment.html_url}"

  pull_request: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'pull_request', callback)

  pull_request_review_comment: (data, callback) ->
    callback "#{data.comment.user.login} commented on a pull request: #{data.comment.html_url}"

  push: (data, callback) ->
    if ! data.created
      callback "#{data.commits.length} new commit(s) pushed by #{data.pusher.name}: #{data.compare}"

  commit_comment: (data, callback) ->
    callback "#{data.comment.user.login} commented on a commit: #{data.comment.html_url}"

  member: (data, callback) ->
    callback "#{data.member.login} has been #{data.action} as a contributor!"

  watch: (data, callback) ->
    callback "#{data.sender.login} has #{data.action} watching #{data.repository.full_name}."

  create: (data, callback) ->
    callback "The #{data.ref} #{data.ref_type} has been created."

  delete: (data, callback) ->
    callback "The #{data.ref} #{data.ref_type} has been deleted."

  fork: (data, callback) ->
    callback "A new fork of #{data.repository.full_name} has been created at #{data.forkee.full_name}."

  team_add: (data, callback) ->
    callback "The #{data.team.name} team now has #{data.team.permission} access to #{data.repository.full_name}"

  release: (data, callback) ->
    callback "#{data.release.name} has been #{data.action}: #{data.release.html_url}"

  page_build: (data, callback) ->
    build = data.build
    if build?
      if build.status is "built"
        callback "#{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "Page build for #{data.repository.full_name} errored: #{build.error.message}."
