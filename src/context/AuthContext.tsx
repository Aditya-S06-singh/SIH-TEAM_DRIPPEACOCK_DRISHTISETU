import React, { createContext, useContext, useState, useEffect } from 'react';
import type { UserProfile, UserRole } from '../types';
import { authService } from '../services/authService';

interface AuthContextType {
  currentUser: UserProfile;
  currentRole: UserRole;
  switchRole: (role: UserRole) => void;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<UserProfile>(() => authService.getCurrentUser() || {
    uid: 'usr_dosje_01',
    name: 'Shri Rajesh Verma (Joint Secretary)',
    email: 'official@drishtisetu.gov.in',
    role: 'dosje_official',
    state: 'Central Headquarters',
    district: 'New Delhi',
    active: true,
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  });

  const switchRole = (role: UserRole) => {
    const updated = authService.switchRole(role);
    setCurrentUser(updated);
  };

  const signOut = async () => {
    await authService.signOut();
    setCurrentUser(authService.switchRole('dosje_official'));
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        currentRole: currentUser.role,
        switchRole,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
