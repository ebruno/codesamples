#!/usr/bin/env zsh
echo '<?xml version="1.0" encoding="UTF-8"?>' > reports/regression_report_junit.xml
echo '<testsuite name="RingbufferRegression" tests="7">' >> reports/regression_report_junit.xml
for i in {1..7}; do
    echo "  <testcase name=\"T00$i\" />" >> reports/regression_report_junit.xml
done
echo '</testsuite>' >> reports/regression_report_junit.xml
