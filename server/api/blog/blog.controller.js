'use strict';

var _ = require('lodash');
var Blog = require('./blog.model');
var Comment = require('../comment/comment.model');

// Get list of blogs
exports.index = function(req, res) {
  Blog.find(function (err, blogs) {
    if(err) { return handleError(res, err); }
    console.log(blogs);
    return res.json(200, blogs);
  });
};

// Get a single blog
exports.show = function(req, res) {
  var comment;
  Blog.findById(req.params.id, function (err, blog) {
    if(err) { return handleError(res, err); }
    if(!blog) { return res.send(404); }
    Comment.find({})
           .where('blog').equals(blog._id) 
           .exec(function (err, comments) {
      if (err) {return handleError(res, err)}
      return res.json({blog: blog, comments: comments});
      blog = blog.toObject();
      blog.comments = [];
      for (comment in comments) {
        add_comment(blog, comments[comment].toObject());
      }
      return res.json(blog);
    });
  });
};

// Creates a new blog in the DB.
exports.create = function(req, res) {
  Blog.create(req.body, function(err, blog) {
    if(err) { return handleError(res, err); }
    return res.json(201, blog);
  });
};

// Updates an existing blog in the DB.
exports.update = function(req, res) {
  if(req.body._id) { delete req.body._id; }
  Blog.findById(req.params.id, function (err, blog) {
    if (err) { return handleError(res, err); }
    if(!blog) { return res.send(404); }
    var updated = _.merge(blog, req.body);
    updated.save(function (err) {
      if (err) { return handleError(res, err); }
      return res.json(200, blog);
    });
  });
};

// Deletes a blog from the DB.
exports.destroy = function(req, res) {
  Blog.findById(req.params.id, function (err, blog) {
    if(err) { return handleError(res, err); }
    if(!blog) { return res.send(404); }
    blog.remove(function(err) {
      if(err) { return handleError(res, err); }
      return res.send(204);
    });
  });
};

function handleError(res, err) {
  return res.send(500, err);
}