{ include("strategy/beliefs_agents.asl") }

!configure_first_strategies.

+!configure_first_strategies
	: true
<-
	.wait( default::actionID(S) & S \== 0 );
	!choose_minimum_well_price;
	.
	
+!set_center_storage_workshop
	: default::minLat(MinLat) & default::minLon(MinLon) & default::maxLat(MaxLat) & default::maxLon(MaxLon) & CLat = (MinLat+MaxLat)/2 & CLon = (MinLon+MaxLon)/2 & new::storageList(SList) & new::workshopList(WList) & rules::closest_facility(SList, CLat, CLon, Storage) & rules::closest_facility(WList, Storage, Workshop)
<-
	+centerStorage(Storage);
	+centerWorkshop(Workshop);
	.print("Closest storage from the center is ",Storage);
	.print("Closest workshop from the storage above is ",Workshop);
	.

+default::well(Well, Lat, Lon, Type, Team, Integrity)
//	: not ataque & .print("aqui") & default::team(MyTeam) & MyTeam == Team & my_role(builder) & default::actionID(Id) 
: default::team(MyTeam) & not .substring(MyTeam, Team) & rules::my_role(builder,CurrentRole) & default::actionID(Id)
<-
	.print(">>>>>>>>>>>>>>>>>>>> I found a well that doesn't belong to my team ",Id);
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
	
	!change_role(CurrentRole,attacker);
	!attack::dismantle_well(Well);
	!change_role(attacker,CurrentRole);
	.

+default::lastAction(Action)
	: default::step(S) & S \== 0 & Action == noAction & new::noActionCount(Count)
<-
	-+new::noActionCount(Count+1);
	.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Step ",S-1," I have done ",Count+1," noActions.");
	-+metrics::noAction(Count+1);
	.
	
+default::massim(Money)
	: rules::my_role(builder,CurrentRole) & not .desire(build::_) & rules::enough_money
<-
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
	
	!build;
	.


+!always_recharge <- !action::recharge_is_new_skip; !always_recharge.

@free[atomic]
//+!free : not free <- +free; !!action::recharge_is_new_skip; .
+!free : not free <- +free; !!always_recharge; .
//+!free : not free <- .print("free added");+free; !!action::recharge_is_new_skip;.
//+!free : free <- !!action::recharge_is_new_skip.
+!free : free & not .desire(_::always_recharge) <- !!always_recharge.
+!free : free.
@notFree[atomic]
+!not_free <- -free.
//+!not_free <- .print("free removed");-free.

+!change_role(OldRole, NewRole)
<-
	leaveRole(OldRole);
	adoptRole(NewRole);
	.
	
// how do we pick a minimum money to start building wells
+!choose_minimum_well_price
	: .findall(Cost,default::wellType(_,Cost,_,_,_),Wells) & .sort(Wells,SortedWells) & .nth(0,SortedWells,MinimumCost)
<-
	-+minimum_money(MinimumCost);
	.
	
// what builders do
+!build 
	: not rules::enough_money & new::chargingList(List) & rules::farthest_facility(List, Facility)
<-
	.print("Going to my farthest charging station",Facility," to explore");
	!action::goto(Facility);
	!action::charge;
	!build;
	.
+!build
<-
	!build::buy_well; 	
	!build;
	.
	
// what delivery agents do 
+!prepare_to_delivery
	: .my_name(Me) & default::play(Me,deliveryagent,_) & .desire(::perform_delivery)
<-
	.print("I'm already working on a delivery task, I'll do it later");
	.
+!prepare_to_delivery
	: .my_name(Me) & default::play(Me,CurrentRole,_)
<-
	!action::forget_old_action(Id);
 	+action::committedToAction(Id);
 	
 	.print("I was a ",CurrentRole);
	
	!strategies::change_role(CurrentRole,deliveryagent);
	!perform_delivery;
	.
+!perform_delivery
	: ::winner(JobId,Deliveries,DeliveryPoint)[source(Initiator)]
<-
	.print("I won the tasks to ",Deliveries," at ",DeliveryPoint);	
	!delivery::delivery_job(JobId,Deliveries,DeliveryPoint);
	
	-::winner(JobId,Deliveries,DeliveryPoint)[source(Initiator)]
	
	!perform_delivery;
	.
+!perform_delivery
<-
	.print("I've finished my deliveries'");
	!strategies::change_role(deliveryagent,gatherer);
	!strategies::always_recharge;
	.
	