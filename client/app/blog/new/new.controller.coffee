'use strict'

angular.module 'mitchDzuganApp'
.controller 'BlogNewCtrl', ($scope, Auth, $location, $http) ->
  $scope.blog = {}
  $scope.errors = {}
  $scope.new_blog = (form) ->
    $scope.submitted = true

    if form.$valid
      console.log $scope.blog
      $http.post('/api/blogs/', $scope.blog).success () ->
        $location.path '/blog'
