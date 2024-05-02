public inherited sharing class MRK_Lists {
    
    public static List<List<Object>> doPartions(List<Object> records, Integer size, Type destType){
        checkNotNull(records);
        checkArgument(size > 0);
        checkNotNull(destType);
        return new Partition(records, size, destType).doPartition();
    }

    private static void checkNotNull(Object reference) {
        if (reference == null) {
            throw new NullPointerException();
        }
    }

    private static void checkArgument(Boolean expression) {
        if (!expression) {
            throw new IllegalArgumentException();
        }
    }

    private class Partition{
        private List<Object> items;
        private Integer splitSize;
        private Type destType;

        Partition(List<Object> records, Integer size, Type destType){
            this.items = records;
            this.splitSize = size;
            this.destType = destType;
        }

        List<List<Object>> doPartition(){
            List<List<Object>> result = (List<List<Object>>)destType.newInstance();
            List<Object> protoList = items.clone();
            protoList.clear();
            List<Object> tempList = protoList.clone();
            Integer index = 0, count = 0, size = items.size();
            while(index < size) {
                tempList.add(items.get(index++));
                ++count;
                if(count == splitSize) {
                    result.add(tempList);
                    tempList = protoList.clone();
                    count = 0;
                }
            }
            if(!tempList.isEmpty()) {
                result.add(tempList);
            }
            return result;
        }
    }

    public class IllegalArgumentException extends Exception {}
}