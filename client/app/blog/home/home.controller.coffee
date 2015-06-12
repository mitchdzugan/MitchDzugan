'use strict'

angular.module 'mitchDzuganApp'
.controller 'BlogHomeCtrl', ($scope, $http, socket) ->
  $scope.blogs = []

  $http.get('/api/blogs').success (blogs) ->
    $scope.blogs = blogs
    socket.syncUpdates 'blogs', $scope.blogs