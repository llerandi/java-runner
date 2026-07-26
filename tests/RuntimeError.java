public class RuntimeError {
    public static void main(String[] args) {
        System.out.println("before crash");
        throw new RuntimeException("intentional runtime error");
    }
}
