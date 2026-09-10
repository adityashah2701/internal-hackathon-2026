/// Provides curated, high-resolution photography URLs for service categories and individual services.
abstract final class ServiceImageHelper {
  /// Returns a high-quality photography image URL for a given category name.
  static String getCategoryImageUrl(String categoryName) {
    final String lower = categoryName.toLowerCase().trim();

    if (lower.contains('electric')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('plumb')) {
      return 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('carpent')) {
      return 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('clean')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('care') || lower.contains('elder')) {
      return 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('appliance') || lower.contains('repair')) {
      return 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('paint')) {
      return 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('mason') || lower.contains('construct')) {
      return 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80';
    } else if (lower.contains('pest')) {
      return 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?auto=format&fit=crop&w=600&q=80';
    }

    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=600&q=80';
  }

  /// Returns a specific image URL for an individual service task.
  static String getServiceImageUrl(String categoryName, String serviceName) {
    final String lowerTask = serviceName.toLowerCase().trim();
    final String lowerCat = categoryName.toLowerCase().trim();

    // Electrical
    if (lowerTask.contains('fan')) {
      return 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('switch') || lowerTask.contains('mcb')) {
      return 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('wiring')) {
      return 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('light') || lowerTask.contains('chandelier')) {
      return 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=400&q=80';
    }

    // Plumbing
    if (lowerTask.contains('tap') || lowerTask.contains('shower')) {
      return 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('drain') || lowerTask.contains('block')) {
      return 'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('leak') || lowerTask.contains('pipe')) {
      return 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('tank') || lowerTask.contains('motor')) {
      return 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=400&q=80';
    }

    // Carpenter
    if (lowerTask.contains('door') || lowerTask.contains('lock')) {
      return 'https://images.unsplash.com/photo-1558002038-1055907df827?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('furniture') || lowerTask.contains('assembly')) {
      return 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('kitchen') || lowerTask.contains('cabinet')) {
      return 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=400&q=80';
    }

    // Cleaning
    if (lowerTask.contains('deep') || lowerTask.contains('sanitation')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('kitchen') || lowerTask.contains('exhaust')) {
      return 'https://images.unsplash.com/photo-1556912172-45b7abe8b7e1?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('bathroom')) {
      return 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('sofa')) {
      return 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?auto=format&fit=crop&w=400&q=80';
    }

    // Caregiver
    if (lowerTask.contains('elder') || lowerTask.contains('vitals')) {
      return 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('physio')) {
      return 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=400&q=80';
    }

    // Appliance
    if (lowerTask.contains('washing')) {
      return 'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('refrigerator')) {
      return 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?auto=format&fit=crop&w=400&q=80';
    } else if (lowerTask.contains('ac') || lowerTask.contains('air')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=400&q=80';
    }

    // Painter
    if (lowerCat.contains('paint')) {
      return 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&w=400&q=80';
    }

    // Default to category image
    return getCategoryImageUrl(categoryName);
  }
}
