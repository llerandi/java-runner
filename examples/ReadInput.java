import java.util.Scanner;

public class ReadInput {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.print("Enter your name: ");
        String name = scanner.nextLine();

        System.out.print("Enter your age: ");
        int age = scanner.nextInt();

        System.out.println("\nHello, " + name + "!");
        System.out.println("In 10 years you will be " + (age + 10) + " years old.");

        scanner.close();
    }
}
