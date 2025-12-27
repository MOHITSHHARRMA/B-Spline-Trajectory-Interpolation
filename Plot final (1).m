function [c, ceq] = circlecon_all_joints(x)
    T = x(1);  % trajectory time

    % Start and end positions (radians)
    start_angles = [-pi/3, -pi/6, 0, -pi/6, -pi/15, -pi/2];
    end_angles   = [2*pi/5, 2*pi/3, -pi/6, -pi/5, pi/4, pi/4];

    % Limits: [velocity; acceleration; jerk]
    vmax = [1.8, 2, 1.5, 2, 2.5, 2];
    amax = [4, 5, 3.5, 4, 5, 4];
    jmax = [20, 25, 20, 20, 30, 25];

    c = [];  % inequality constraints
    ceq = []; % equality constraints

    for i = 1:6
        theta = abs(end_angles(i) - start_angles(i));
        
        % Velocity, Acceleration, Jerk constraint from 7th degree polynomial
         v = abs((35 * theta) / (16 * T));
        a = abs((84 * sqrt(5) / 25) * (theta / T^2));
         j = abs((105 / 2) * (theta / T^3));

      
        c(end+1) = v - vmax(i);
        c(end+1) = a - amax(i);
        c(end+1) = j - jmax(i);
    end
end

% Main optimization script
clc; clear; close all;

x0 = 5;         % initial guess for time
lb = 0.1;
ub = 10;

options = optimoptions('fmincon','Display','iter','Algorithm','sqp');

% Solve optimization
[x_opt, fval] = fmincon(@(x)x(1), x0, [], [], [], [], lb, ub, @circlecon_all_joints, options);
fprintf('Optimal time T = %.4f seconds\n', x_opt);
%% clc; clear; close all;

% Optimized trajectory time
T_opt = 2.8634;  % use value from optimization

% Define symbolic variables
syms a b c d e f g h x
F = a + b*x + c*x^2 + d*x^3 + e*x^4 + f*x^5 + g*x^6 + h*x^7;
V = diff(F, x);
A = diff(F, x, 2);
J = diff(F, x, 3);

coeffs_vars = [a b c d e f g h];
exprs = [F; V; A; J];

% Generate symbolic constraint matrix at t0 and tf
t0 = 0; tf = T_opt;
constraint_matrix = sym(zeros(8,8));
for i = 1:4
    constraint_matrix(i, :) = subs(jacobian(exprs(i), coeffs_vars), x, t0);
    constraint_matrix(i+4, :) = subs(jacobian(exprs(i), coeffs_vars), x, tf);
end
constraint_matrix = double(constraint_matrix);

% Boundary conditions: [q0, qf] for each joint
Y = [
    -pi/3  2*pi/5;
    -pi/6  2*pi/3;
    0     -pi/6;
    -pi/6  -pi/5;
    -pi/15 pi/4;
    -pi/2  pi/4
];

% Solve for coefficients of each joint
coeffs_all = zeros(6, 8);
for joint = 1:6
    Yj = [Y(joint,1); 0; 0; 0; Y(joint,2); 0; 0; 0];
    coeffs_joint = constraint_matrix \ Yj;
    coeffs_all(joint, :) = coeffs_joint.';
end

% Time vector for plotting
t = linspace(t0, tf, 200);

% Initialize storage
all_q = zeros(6, length(t));
all_dq = zeros(6, length(t));
all_ddq = zeros(6, length(t));
all_jerk = zeros(6, length(t));

% Generate motion profiles
for joint = 1:6
    coeffs = coeffs_all(joint, :);
    coeffs_poly = flip(coeffs);  % for polyval

    q = polyval(coeffs_poly, t);
    dq = polyval(polyder(coeffs_poly), t);
    ddq = polyval(polyder(polyder(coeffs_poly)), t);
    jerk = polyval(polyder(polyder(polyder(coeffs_poly))), t);

    all_q(joint, :) = q;
    all_dq(joint, :) = dq;
    all_ddq(joint, :) = ddq;
    all_jerk(joint, :) = jerk;
end

% Joint colors for consistency
joint_colors = lines(6);

% Plot displacement
figure;
subplot(4,1,1);
hold on;
for joint = 1:6
    plot(t, all_q(joint, :), 'Color', joint_colors(joint,:), 'LineWidth', 2);
end
title('Displacement for all joints');
xlabel('Time (s)'); ylabel('q(t) [rad]');
legend('Joint 1','Joint 2','Joint 3','Joint 4','Joint 5','Joint 6');
grid on;

% Plot velocity
subplot(4,1,2);
hold on;
for joint = 1:6
    plot(t, all_dq(joint, :), 'Color', joint_colors(joint,:), 'LineWidth', 2);
end
title('Velocity for all joints');
xlabel('Time (s)'); ylabel('dq/dt [rad/s]');
grid on;

% Plot acceleration
subplot(4,1,3);
hold on;
for joint = 1:6
    plot(t, all_ddq(joint, :), 'Color', joint_colors(joint,:), 'LineWidth', 2);
end
title('Acceleration for all joints');
xlabel('Time (s)'); ylabel('d²q/dt² [rad/s²]');
grid on;

% Plot jerk
subplot(4,1,4);
hold on;
for joint = 1:6
    plot(t, all_jerk(joint, :), 'Color', joint_colors(joint,:), 'LineWidth', 2);
end
title('Jerk for all joints');
xlabel('Time (s)'); ylabel('d³q/dt³ [rad/s³]');
grid on;
%% vmax = [1.8, 2, 1.5, 2, 2.5, 2];
amax = [4, 5, 3.5, 4, 5, 4];
jmax = [20, 25, 20, 20, 30, 25];

for i = 1:6
    fprintf("Joint %d: max vel = %.2f, acc = %.2f, jerk = %.2f\n", ...
        i, max(abs(all_dq(i,:))), max(abs(all_ddq(i,:))), max(abs(all_jerk(i,:))));
end

% Average values for velocity, acceleration, and jerk

for i = 1:6
    avg_vel = mean(abs(all_dq(i,:)));
    avg_acc = mean(abs(all_ddq(i,:)));
    avg_jerk = mean(abs(all_jerk(i,:)));

    fprintf("Joint %d: avg vel = %.4f, avg acc = %.4f, avg jerk = %.4f\n", ...
        i, avg_vel, avg_acc, avg_jerk);
end

%% % Joint numbers
joints = 1:6;

% Max values (already given)
max_vel = [1.8, 0.4, 0.4, 0.8, 1.8, 0.6];
max_acc = [2.1, 0.48, 0.48, 0.96, 2.2, 0.72];
max_jerk = [5.4, 1.2, 1.2, 2.4, 5.5, 1.8];

% Avg values (already given)
avg_vel = [0.8006, 0.9097, 0.1819, 0.0364, 0.3457, 0.8188];
avg_acc = [1.2232, 1.3900, 0.2780, 0.0556, 0.5282, 1.2510];
avg_jerk = [2.9337, 3.3338, 0.6668, 0.1334, 1.2668, 3.0004];

% Plot histograms
figure('Name','Velocity, Acceleration, and Jerk Comparison','NumberTitle','off');

subplot(3,1,1);
bar(joints, [max_vel; avg_vel]');
title('Velocity Comparison');
ylabel('Velocity (rad/s)');
legend('Max Velocity','Avg Velocity');
grid on;

subplot(3,1,2);
bar(joints, [max_acc; avg_acc]');
title('Acceleration Comparison');
ylabel('Acceleration (rad/s^2)');
legend('Max Acceleration','Avg Acceleration');
grid on;

subplot(3,1,3);
bar(joints, [max_jerk; avg_jerk]');
title('Jerk Comparison');
ylabel('Jerk (rad/s^3)');
xlabel('Joint Number');
legend('Max Jerk','Avg Jerk');
grid on;

