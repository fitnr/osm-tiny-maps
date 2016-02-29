[out:xml][timeout:60];
(
    way[highway=cycleway]({{bbox}});
    way["leisure"="park"]({{bbox}});
);
(
    ._;
    >;
);
out {{verbosity}} qt;
