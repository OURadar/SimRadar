#!/bin/bash


function cocomo() {
    totalLines="$1"
    annualSalary="$2"
    if [ -z "$2" ]; then
        annualSalary="56268"
    fi
    annualSalaryString=$(printf "%'.f\n" ${annualSalary})
    # COCOMO
    personMonths=$(echo "scale=4; 2.4 * e(1.05 * l(${totalLines} * 0.001))" | bc -l)
    personYears=$(echo "scale=4; ${personMonths} / 12.0" | bc)
    scheduleMonths=$(echo "scale=4; 2.5 * e(0.38 * l(${personMonths}))" | bc -l)
    scheduleYears=$(echo "scale=4; ${scheduleMonths} / 12" | bc)
    developerCount=$(echo "scale=4; ${personMonths} / ${scheduleMonths}" | bc)
    cost=$(echo "scale=2; 2.4 * ${personYears} * ${annualSalary}" | bc)
    cost=$(printf "%'.f\n" ${cost})
    # Hightlight & reset
    HL="\033[38;5;82m"
    RS="\033[0m"

    echo -e "Total Physical Source Lines of Code (SLOC) = ${HL}$(printf "%'.f\n" ${totalLines})${RS}"
    echo -e "Development Effort Estimate, Person-Years (Person-Months) = ${personYears} (${HL}${personMonths}${RS})"
    echo " (Basic COCOMO model, Person-Months = 2.4 * (KSLOC**1.05))"
    echo -e "Schedule Estimate, Years (Months)                         = ${scheduleYears} (${HL}${scheduleMonths}${RS})"
    echo -e " (Basic COCOMO model, Months = 2.5 * (person-months**0.38))"
    echo "Estimated Average Number of Developers (Effort/Schedule)  = ${developerCount}"
    echo "Total Estimated Cost to Develop                           = \$ ${cost}"
    echo -e "(average salary = ${HL}\$${annualSalaryString}${RS}/year, overhead = 2.40)."
}

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -s|--set-salary)
            annualSalary="$2"
            shift
            ;;
        -m|--modern-salary)
            # Retrieve from Google: average salary of computer programmers from 2016 is $85,180
            annualSalary="85180"
            shift
            ;;
        -h|--help)
            exit
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

LC_NUMERIC=en_US

kk=0
lines=()
while IFS= read line; do
    lines[${kk}]="${line}"
    if [[ ${line} == SUM* ]]; then
        totalLines=${line##* }
    fi
    kk=$((kk+1))
done < <(cloc --exclude-dir=lib --exclude-lang=HTML,XML,Ruby,"Bourne Again Shell" --quiet .)

printf "%s\n" "${lines[@]}"
echo ""

if [ ! -z "${annualSalary}" ]; then
    echo "Using Custom Salary:"
    echo "--------------------"
else
    echo "Using Salary from 2014:"
    echo "-----------------------"
fi

cocomo "${totalLines}" "${annualSalary}"

echo ""
echo "Copyright (c) 2018 Boonleng Cheong"
echo "Based on COCOMO (organic, https://en.wikipedia.org/wiki/COCOMO)"
echo "Outoupt generated to match the original sloccount tool by David A. Wheeler"
echo "This script comes with ABSOLUTELY NO WARRANTY. You are welcome to redistribute"
echo "it under certain conditions as specified by the GNU GPL license;"
