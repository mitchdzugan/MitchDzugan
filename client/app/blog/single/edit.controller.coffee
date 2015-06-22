'use strict'

angular.module 'mitchDzuganApp'
.controller 'BlogEditCtrl', ($scope, $http, socket, $stateParams, $location) ->
	$scope.blog = {}

	$http.get('/api/blogs/' + $stateParams.id).success (blog) ->
		$scope.blog = blog
		socket.syncUpdates 'blog', $scope.blog

	$scope.edit_blog = (form) ->
		$scope.submitted = true

		if form.$valid
			$http.put('/api/blogs/' + $scope.blog._id, $scope.blog).success () ->
				$location.path '/blog'