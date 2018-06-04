+!commit_action(Action)
	: default::actionID(Id) & action::action_sent(Id) & metrics::next_actions(C) & default::step(Step)
<-
	.print("I've already sent an action at step ",Step,", I cannot send a new one ", Action);
	-+metrics::next_actions(C+1); 
	.wait({-default::actionID(_)}); 
	!commit_action(Action);
	.
+!commit_action(Action)
	: default::actionID(Id) & not action::action(Id,_) 
<-
	.abolish(action::action(_,_)); // removes all the possible last actions
	+action::action(Id,Action);
	chosenAction(Id);
//	.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
//	if ( Action \== recharge & Action \== continue) {
//		.print("Doing action ",Action, " at step ",S," . Waiting for step ",S+1);
//	}
	
	!!wait_request_for_help(Id)
	.wait( default::actionID(Id2) & Id2 \== Id & not action::reasoning_about_belief(_)); 
	
	-action::action(Id,Action);
	-action::action_sent(Id);
	
	?default::lastActionResult(Result);
	.print("Last action result was: ",Result);
		
	if (Action \== recharge & Action \== continue & not .substring("deliver",Action) & not .substring("assist_assemble",Action) & not .substring("buy",Action) & not .substring("bid_for_job",Action) & Result \== successful) {
		.print("Failed to execute action ",Action," with actionId ",Id,". Executing it again.");
		!commit_action(Action);
	}
	else {
		if (.substring("deliver",Action) & Result == failed ) { !commit_action(Action); }
		if (.substring("deliver",Action) & Result \== failed_job_status & default::winner(_, assemble(_, JobId, _))) { +strategies::jobDone(JobId); }
		if (strategies::free) { !!action::recharge_is_new_skip; }
	}
	.
+!commit_action(Action) : Action == recharge.
	
@forgetAction[atomic]
+!forget_old_action(ActionId)
	: action::action(ActionId,Action)
<-
	.drop_intention(action::wait_request_for_help(ActionId));
	.drop_intention(action::commit_action(Action)); // we don't want to follow these plans anymore
	-action::action(ActionId,Action);
	!forget_old_action(Step);
	.
+!forget_old_action(ActionId).

+default::chosenActions(ActionId, Agents) // all the agents have chosen their actions
	: .length(Agents) == 34
<-
	.drop_intention(action::wait_request_for_help(ActionId));
	!send_action_to_server(ActionId);
	.
+!wait_request_for_help(ActionId)
	: action::committedToAction(ActionId)
<-
	!send_action_to_server(ActionId);
	.abolish(action::committedToAction(_));
	.	
+!wait_request_for_help(ActionId)
<-
	.wait(1000);
	!send_action_to_server(ActionId);
	.	
	
@sendAction[atomic]
+!send_action_to_server(ActionId)
	: not action::action_sent(ActionId) & action::action(ActionId,Action) & default::step(Step)
<-
	.print("Sending ",Step," ",Action);
	action(Action);
	+action::action_sent(ActionId);
	.
+!send_action_to_server(ActionId). // action already sent to the server

