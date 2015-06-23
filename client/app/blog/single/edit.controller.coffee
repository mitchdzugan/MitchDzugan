'use strict'

angular.module 'mitchDzuganApp'
.controller 'BlogEditCtrl', ($scope, $http, $sce, socket, $stateParams, $location) ->
	$scope.blog = {}

	$http.get('/api/blogs/' + $stateParams.id).success (res) ->
		$scope.blog = res.blog
		socket.syncUpdates 'blog', $scope.blog

	$scope.edit_blog = (form) ->
		$scope.submitted = true

		if form.$valid
			$http.put('/api/blogs/' + $scope.blog._id, $scope.blog).success () ->
				$location.path '/blog'

	$scope.marked = -> 
		if ($scope.blog.body)
			$sce.trustAsHtml(marked $scope.blog.body)
		else
			$scope.blog.body