// Single-line comment
[out:xml][timeout:60];
(
    way[highway=cycleway]({{bbox}});
    way["leisure"="park"]({{bbox}});
);
(
    ._;
    >;
);
/*
 Multi-line
 comment
*/
out {{verbosity}} qt;
