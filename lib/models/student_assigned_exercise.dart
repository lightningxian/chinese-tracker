import 'exercise.dart';
import 'exercise_assignment.dart';

class StudentAssignedExercise {
  const StudentAssignedExercise({
    required this.exercise,
    required this.assignment,
  });

  final Exercise exercise;
  final ExerciseAssignment assignment;
}
