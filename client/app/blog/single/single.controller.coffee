'use strict'

add_comment = (blog, new_comment) ->
  parent = blog
  for ancestor in new_comment.ancestors
    found_parent = false
    for comment in parent.comments
      if comment._id.toString() == ancestor.toString()
        parent = comment
        found_parent = true
        break
    if !found_parent
      parent.comments.push
        _id: ancestor,
        comments: []
      parent = parent.comments[parent.comments.length-1]
  comment_exists = false
  for comment in parent.comments
    if comment._id == new_comment._id
      comment_exists = true
      comment.ancestors = new_comment.ancestors
      comment.author = new_comment.author
      comment.blog = new_comment.blog
      comment.body = new_comment.body
      comment.hidden = true
      comment.reply = {}
      break
  if !comment_exists
    new_comment.comments = []
    new_comment.hidden = true
    new_comment.reply = {}
    parent.comments.push new_comment

angular.module 'mitchDzuganApp'
.controller 'BlogSingleCtrl', ($scope, $sce, $http, socket, $stateParams, Auth) ->
  $scope.isLoggedIn = Auth.isLoggedIn
  $scope.isAdmin = Auth.isAdmin
  $scope.getCurrentUser = Auth.getCurrentUser

  $scope.blog = {hidden: true, reply: {}}
  $scope.new_comment = {}
  $scope.res = {}

  build_blog = ->
    $scope.blog = $scope.res.blog
    $scope.blog.comments = []
    $scope.blog.hidden = true
    $scope.blog.reply = {}
    for comment in $scope.res.comments
      add_comment $scope.blog, comment

  $http.get('/api/blogs/' + $stateParams.id).success (res) ->
    $scope.res = res
    build_blog()

  $scope.marked = -> 
    if ($scope.blog.body)
      $sce.trustAsHtml(marked $scope.blog.body)
    else
      $scope.blog.body

  $scope.add_comment = (comment, form) ->
    if form.$valid
      $scope.new_comment.blog = $scope.blog._id
      $scope.new_comment.parent = comment._id
      $scope.new_comment.author = comment.reply.author
      $scope.new_comment.body = comment.reply.body
      if $scope.isLoggedIn()
        $scope.new_comment.author_id = $scope.getCurrentUser()._id
      $http.post('/api/comments/', $scope.new_comment)
        .success (res) ->
          add_comment $scope.blog, res
          comment.hidden = true
        .error (res) ->
          comment.error = res

  $scope.set_hidden = (comment, b) ->
    comment.hidden = b
