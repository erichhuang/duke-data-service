/** @jsx React.DOM */
var RouteHandler = ReactRouter.RouteHandler;

var App = React.createClass({
  getInitialState: function() {
    return {
      api_token: ''
    };
  },

  render: function() {
    return (
      <div>
        <h1>Duke Data Services</h1>
        <p>service_id: {this.props.service_id}</p>
        <RouteHandler />
      </div>
    )
  }
});
