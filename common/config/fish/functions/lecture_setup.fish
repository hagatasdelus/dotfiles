function lecture_setup --description 'Setup directory structure for university courses'
    if test (count $argv) -lt 1
        echo "Error: Command failed. Specify one or more course names." >&2
        return 1
    end

    for course in $argv
        mkdir -p "$course/lectures" "$course/reports" "$course/tests" "$course/pastexams"

        for i in (seq -w 1 15)
            mkdir -p "$course/lectures/$i"
        end
        echo "Course Setup Done >> $course"
    end
end
