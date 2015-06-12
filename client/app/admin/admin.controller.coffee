'use strict'

angular.module 'mitchDzuganApp'
.controller 'AdminCtrl', ($scope, $http, Auth, User) ->

  $http.get '/api/users'
  .success (users) ->
    $scope.users = users

  $scope.delete = (user) ->
    User.remove id: user._id
    _.remove $scope.users, user