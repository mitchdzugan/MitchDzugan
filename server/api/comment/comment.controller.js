'use strict';

var _ = require('lodash');
var Comment = require('./comment.model');
var User = require('../user/user.model');

// Get list of comments
exports.index = function(req, res) {
  Comment.find(function (err, comments) {
    if(err) { return handleError(res, err); }
    return res.json(200, comments);
  });
};

// Get a single comment
exports.show = function(req, res) {
  Comment.findById(req.params.id, function (err, comment) {
    if(err) { return handleError(res, err); }
    if(!comment) { return res.send(404); }
    return res.json(comment);
  });
};

// Creates a new comment in the DB.
exports.create = function(req, res) {
  var create_comment = function() {
    if (req.body.body) {
      Comment.create(req.body, function(err, comment) {
        if(err) { return handleError(res, err); }
        return res.json(201, comment);
      });
    } else {
      return handleError(res, {message: "Comment must have a body"});
    }
  }

  var author_inject = function() {
    if (req.body.author_id) {
      User.findById(req.body.author_id, function(err, user) {
        if(err) { return handleError(res, err); }
        req.body.author = user.name;
        return create_comment();
      });
    } else {
      if (req.body.author) {
        return create_comment();
      } else {
        return handleError(res, {message: "Comment must have an author"});
      }
    }
  };

  console.log(req.body);
  if (req.body.blog === req.body.parent) {
    req.body.ancestors = []
    return author_inject();
  } else {
    Comment.findById(req.body.parent, function(err, comment) {
      if(err) { return handleError(res, err); }
      req.body.ancestors = comment.ancestors.concat(comment._id);
      return author_inject();
    });
  }
};

// Updates an existing comment in the DB.
exports.update = function(req, res) {
  if(req.body._id) { delete req.body._id; }
  Comment.findById(req.params.id, function (err, comment) {
    if (err) { return handleError(res, err); }
    if(!comment) { return res.send(404); }
    var updated = _.merge(comment, req.body);
    updated.save(function (err) {
      if (err) { return handleError(res, err); }
      return res.json(200, comment);
    });
  });
};

// Deletes a comment from the DB.
exports.destroy = function(req, res) {
  Comment.findById(req.params.id, function (err, comment) {
    if(err) { return handleError(res, err); }
    if(!comment) { return res.send(404); }
    comment.remove(function(err) {
      if(err) { return handleError(res, err); }
      return res.send(204);
    });
  });
};

function handleError(res, err) {
  return res.send(500, err);
}