import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';

class SendReminder extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showReportReminderModal: false,
    };
    this.toggleReportReminderModal = this.toggleReportReminderModal.bind(this);
    this.sendReminder = this.sendReminder.bind(this);
  }

  toggleReportReminderModal() {
    let current = this.state.showReportReminderModal;
    this.setState({
      showReportReminderModal: !current,
    });
  }

  sendReminder() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/reminder', {})
      .then(() => {
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        reportError(error);
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>You are about to send a report reminder to this monitoree.</p>
          <p>
            <b>You can only send one reminder per monitoree per 24 hours.</b> Are you sure you want to do this?
          </p>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit}>
            Send
          </Button>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button onClick={this.toggleReportReminderModal} className="ml-2" disabled={this.props.disabled}>
          <i className="fas fa-bell"></i> Send Report Reminder
        </Button>
        {this.state.showReportReminderModal && this.createModal('Send Report Reminder', this.toggleReportReminderModal, this.sendReminder)}
      </React.Fragment>
    );
  }
}

SendReminder.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  disabled: PropTypes.bool,
};

export default SendReminder;
