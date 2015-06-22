'use strict'

angular.module 'mitchDzuganApp'
.controller 'BlogHomeCtrl', ($scope, $http, socket, $location, Auth) ->
  $scope.blogs = []

  $scope.isAdmin = Auth.isAdmin

  $scope.delete = (id) -> $http.delete('/api/blogs/' + id)

  $http.get('/api/blogs').success (blogs) ->
    $scope.blogs = blogs
    socket.syncUpdates 'blog', $scope.blogs