'use strict'

angular.module 'mitchDzuganApp'
.controller 'BlogSingleCtrl', ($scope, $http, socket, $stateParams) ->
  $scope.blog = {}

  $http.get('/api/blogs/' + $stateParams.id).success (blog) ->
    $scope.blog = blog
    socket.syncUpdates 'blog', $scope.blog