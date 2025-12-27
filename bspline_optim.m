

% Optimization
fun = @(t) t(13);
% nonlcon = @mintimetraj;
% A = [];
% b = [];
% Aeq = [2 1 -1];
% beq = [0];
% 
% % x0 = [0 0.15 0 0 0.15 0 0 0.15 0 0 0.15 0 0 0.15 0 0 0.15 0 0.15]
% 
% x0 = [0 0 0]
% lb = [0 0 0]
% ub = [inf inf inf];

nonlcon = @mintimetraj;
A = [];
b = [];
Aeq = [2 1 0 0 0 0 0 0 0 0 0 0 -1
       0 0 2 1 0 0 0 0 0 0 0 0 -1
       0 0 0 0 2 1 0 0 0 0 0 0 -1
       0 0 0 0 0 0 2 1 0 0 0 0 -1
       0 0 0 0 0 0 0 0 2 1 0 0 -1
       0 0 0 0 0 0 0 0 0 0 2 1 -1
     ];
beq = [0; 0; 0; 0; 0; 0];

% x0 = [0 0.15 0 0 0.15 0 0 0.15 0 0 0.15 0 0 0.15 0 0 0.15 0 0.15]

x0 = [0 0 0 0 0 0 0 0 0 0 0 0 0]
lb = [0 0 0 0 0 0 0 0 0 0 0 0 0]
ub = [inf inf inf inf inf inf inf inf inf inf inf inf inf];

[x,fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon)
% [x,fval,exitflag,output,lambda,grad,hessian] = fmincon(@myobj,x0,A,b,Aeq,beq,lb,ub,nonlcon);